ENV["RACK_ENV"] = 'test'

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => {username: "admin"} }
  end

  def test_index
    create_document "about.txt"
    create_document "history.txt"
    create_document "changes.txt"
    create_document "murakami.md"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "murakami.md"
  end

  def test_file_page
    create_document "about.txt", "Memories warm you up"

    get "/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Memories warm you up"
  end

  def test_file_does_not_exist
    get "/myownfile"
    assert_equal 302, last_response.status

    assert_equal "myownfile does not exist.", session[:message]
  end

  def test_redering_markdown_file
    create_document "murakami.md", "# I am in love with Murakami"

    get "/murakami.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>I am in love with Murakami</h1>"
  end

  def test_editing_file
    create_document "about.txt"

    get "/about.txt/edit", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Edit contents of 'about.txt'"
  end

  def test_editing_document_signed_out
    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_updating_document
    post "/about.txt", new_content: "Memories warm you up"
    assert_equal 302, last_response.status
    assert_equal "about.txt has been updated.", session[:message]

    get "/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Memories warm you up"
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    post "/new", name: "murakami.md"
    assert_equal 302, last_response.status
    assert_equal "murakami.md was created.", session[:message]

    get "/"
    assert_includes last_response.body, "murakami.md"
  end

  def test_deleting_document
    create_document("test.txt")

    get "/test.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_sign_in_page
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Username:"
    assert_includes last_response.body, "Password:"
  end

  def test_submitting_sign_in_form
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]


    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_sign_in_with_wrong_credentials
    post "/users/signin", username: "balal", password: "naeem"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials!"
  end

  def test_signout
    get "/", {}, {"rack.session" => {username: "admin"} }
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_equal "You have been signed out.", session[:message]

    get last_response["Location"]
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end
end





















