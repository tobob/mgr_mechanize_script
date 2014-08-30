require 'mechanize'
require 'bundler'
Bundler.require(:default)

#constants

HITS = 40
TIME = 3
LOOPS = 5

class PhantomUser
  def initialize(ip, time)
    @post_id = nil
    @time = time
    @ip = ip
    @agent = Mechanize.new
    @whole_time = 0
    @text_generator = LoremIpsum::Generator.new
  end

  def perform_work
    sleep(@time)
    visit_posts
    next_pagination_page
    create_post
    edit_post
    create_comment
    delete_comment
  end

  def init_time
    @start_time = Time.now
  end

  def count_time
    @whole_time += (Time.now - @start_time)
  end

  def visit_posts
    init_time
    @agent.get(@ip+"/posts")
    count_time
  end

  def next_pagination_page
    init_time
    doc = @agent.page
    link = doc.link_with(text: "Next ›")
    link = doc.link_with(text: "Next →")
    link.click unless link.nil?
    count_time
  end

  def create_post
    init_time
    doc = @agent.page
    doc.link_with(text: "New Post").click
    form = @agent.page.form
    title_input = form.field_with(id: "post_title")
    title_input.value = @text_generator.generate({words: 10})
    content_input = form.field_with(id: "post_content")
    content_input.value = @text_generator.generate({words: 20})
    form.submit
    @post_id = @agent.page.uri.to_s[/posts\/[\d]*/][6 .. -1]
    count_time
  end

  def edit_post
    init_time
    doc = @agent.page
    doc.link_with(text: "Edit").click
    form = @agent.page.form
    content_input = form.field_with(id: "post_content")
    content_input.value = "NEW TEXT FOR POST! LOREM IPSUM"
    form.submit
    count_time
  end

  def create_comment
    init_time
    doc = @agent.page
    form = doc.form
    content_input = form.field_with(id: "comment_content")
    content_input.value = "THIS IS COMMENT"
    form.submit
    count_time
  end

  def delete_comment
    init_time
    doc = @agent.page
    href = doc.link_with(text: "Delete Comment").href
    @agent.delete(@ip+href)
    count_time
  end

  def report
    p @whole_time
  end
end

def one_worker(time)
  phantom = PhantomUser.new("http://157.158.169.22", time)
  phantom.perform_work
  phantom.report
end

config_array = [
  [ 1, 1, 5 ]
]
i = 0
config_array.each do |config_line|
  generator = LoremIpsum::Generator.new
  i = i + 1
  p "Case ##{i}"
  threads = []
  config_line[2].times do |i|
    config_line[0].times do
      t = Thread.new{one_worker(i*config_line[1])}
      threads << t
    end
  end
  threads.each {|t| t.join}
end
