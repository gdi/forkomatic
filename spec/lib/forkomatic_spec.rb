require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Forkomatic do
  before do
    @forkomatic = Forkomatic.new({:max_children => 5, :wait_for_children => false, :max_iterations => 1})
  end

  describe '.new' do
    it "should create a forkomatic from the params" do
      @forkomatic.should be_a_kind_of(Forkomatic)
    end
    it "should set max_iterations to 1" do
      @forkomatic.max_iterations.should == 1
    end
    it "should create a forkomatic intialized with an integer" do
      @forkomatic.available.should == 5
    end
    it "should create a forkomatic initialized with a hash" do
      @test = Forkomatic.new({'max_runners' => 1})
      @test.available.should == 1
    end
    it "should create a forkomatic initalized with a file path to a configuration" do
      @test = Forkomatic.new(File.dirname(__FILE__) + '/../fixtures/config.txt')
      @test.available.should == 2
    end
    it "should not wait for children if :wait_for_children is false" do
      @forkomatic.wait_for_children.should == false
    end
  end
end
