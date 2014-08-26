require 'mechanize'

class PhantomUser
  def initialize(ip, time)
    p time
    @time = time
    @ip = ip
    @agent = Mechanize.new
    @whole_time = 0
  end
  
  def perform_work
    sleep(@time)
    visit_posts 
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
  
  def report
    p @whole_time
  end
end

def one_worker(time)
  phantom = PhantomUser.new("http://localhost", time)
  phantom.perform_work
  phantom.report
end
threads = []
10.times do |i|
  5.times do
    t = Thread.new{one_worker(i*5)}
    threads << t
  end
end
threads.each {|t| t.join}
