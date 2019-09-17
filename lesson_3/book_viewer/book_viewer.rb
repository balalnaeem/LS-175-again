require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

before  do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(content)
    content.split("\n\n").map.with_index do |line, index|
      "<p id='paragraph#{index}'>#{line}</p>"
    end.join
  end
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield(number, name, contents)
  end
end

def chapters_matching(query)
  results = []
  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      matches[index] = paragraph if paragraph.include? query
    end
    results << {number: number, name: name, paragraph: matches} if matches.any?
  end

  results
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  @ch_number = params[:number].to_i
  @title = "Chapter #{@ch_number}"

  redirect "/" unless (1..@contents.size).cover? @ch_number

  @chapter_content = File.read("data/chp#{@ch_number}.txt")
  erb :chapter
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end