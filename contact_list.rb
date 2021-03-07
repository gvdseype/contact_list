require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

root = File.expand_path("..", __FILE__)

before do
  session[:list] ||= {}
  session[:categories] ||= []
end

helpers do
  def users_from_cat(input_cat) #used in category_page to give list of all contacts in that category
    array = []
    session[:list].each do |contact, details|
      if details[:category] == input_cat
        array << contact
      end
    end
    array
  end

  def replace_key(old_name, new_name)
    session[:list][:new_name] = session[:list].delete(old_name)
  end
end

get "/" do
  erb :homepage, layout: :homepage_layout
end

get "/contacts/:contact_name" do
  @contact_person = params[:contact_name].to_sym
  
  erb :contact_page
end

get "/category_page/:category_name" do
  @category_type = params[:category_name] 

  erb :category_page
end

get "/new" do

  erb :new_contact
end

post "/create" do
  name = params[:name].to_sym
  number_value = params[:number]
  email_value = params[:email]
  category_value = params[:category]

  session[:list][name] = {number: number_value, email: email_value, category: category_value }
  session[:categories] << category_value if !session[:categories].include?(category_value)

  redirect "/"
end

post "/delete/:contact_name" do

  contact_name = params[:contact_name].to_sym
  category_of_the_contact = session[:list][contact_name][:category]

  # Delete category if that was the only user
  # of that category
  if users_from_cat(category_of_the_contact).size == 1
    session[:categories].delete(category_of_the_contact)
  end

  session[:list].delete(contact_name)
  redirect "/"
end

# edit an existing contact
get "/contacts/:contact_person/edit" do
  @contact_name = params[:contact_person].to_sym
  @number_value = session[:list][@contact_name][:number]
  @email_value = session[:list][@contact_name][:email]
  @category_value = session[:list][@contact_name][:category]
  
  erb :edit_contact, layout: :layout
end

#update an existing contact list
post "/edit/:contact_person" do
  person = params[:contact_person].to_sym
  @contact_hash = session[:list][person]
  former_category = @contact_hash[:category]

  person_name = params[:name]
  person_number_value = params[:number]
  person_email_value = params[:email]
  person_category_value = params[:category]

  @contact_hash[:email] = person_email_value
  @contact_hash[:number] = person_number_value
  @contact_hash[:category] = person_category_value

  session[:list][params[:name]] = session[:list].delete(person)
  session[:categories][session[:categories].index(former_category)] = person_category_value
  redirect "/"
end