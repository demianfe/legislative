require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe BillsController do

  # This should return the minimal set of attributes required to create a valid
  # Bill. As you add validations to Bill, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {  }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # BillsController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    it "#index redirects to search" do
      get :index, {:locale => 'es'}, valid_session
      response.should redirect_to :action => :searches
    end
  end
  describe "#get_author_related_info" do
    before :each do
      
    end
    it('gets the information based on the name of an author') do
      response = '[{
      "uid":"5330377bd0c05d8b737b6de0",
      "name":"Roberto Poblete Zapata"}]'
      stub_request(:get, /.*morph.io*/)
        .to_return(:body => response)
      controller = BillsController.new
      extra_info = controller.instance_eval{ get_author_related_info "Jaramillo Becker, Enrique" }
      extra_info['uid'].should eql "5330377bd0c05d8b737b6de0"
      extra_info['name'].should eql "Enrique Jaramillo Becker"
    end
    it('if morph doesnt have the person') do
      response = '[]'
      stub_request(:get, /.*morph.io*/)
        .to_return(:body => response)
      controller = BillsController.new
      extra_info = controller.instance_eval{ get_author_related_info "Jaramillo Becker, Enrique" }
      extra_info['uid'].should be_nil
      extra_info['name'].should eql "Enrique Jaramillo Becker"
    end
    it('if morph returns more than one person') do
      response = '[{
      "uid":"5330377bd0c05d8b737b6de0",
      "name":"Roberto Poblete Zapata"},{
      "uid":"a",
      "name":"hello"}]'
      stub_request(:get, /.*morph.io*/)
        .to_return(:body => response)
      controller = BillsController.new
      extra_info = controller.instance_eval{ get_author_related_info "Jaramillo Becker, Enrique" }
      extra_info['uid'].should eql "5330377bd0c05d8b737b6de0"
      extra_info['name'].should eql "Enrique Jaramillo Becker"
    end
  end

  describe "GET show" do
    it "assigns the requested bill as @bill" do
      bill = Billit::Bill.get(ENV['billit_url'] + "6967-06.json", 'application/json')

      get :show, {:id => bill.uid, :locale => 'es'}, valid_session
      assigns(:paperworks).should_not be_nil
      assigns(:bill).should_not be_nil
      assigns(:bill).uid.should eq(bill.uid)
      assigns(:bill).should be_an_instance_of Billit::Bill
      assigns(:title).should eq bill.title + ' - '
      #Muestra la zona morada
      assigns(:condition_bill_header).should be true
      #assigns(:authors).should_not be_nil

    end


    it "returns @date_freq as an array of integers" do
      bill = Billit::Bill.get(ENV['billit_url'] + "6967-06.json", 'application/json')
      # bill = Bill.create! valid_attributes
      get :show, {:id => bill.uid, :locale => 'es'}, valid_session
      assigns(:date_freq).should be_an_instance_of Array
      assigns(:date_freq).length.should be ENV['bill_graph_data_length'].to_i
      assigns(:date_freq).each do |freq|
        freq.should be_an Integer
      end
    end

    it "assigns @date_freq values according to defined time intervals" do
      bill = Billit::Bill.get(ENV['billit_url'] + "6967-06", 'application/json')
      Date.stub(:today) {Date.new(2013, 4)}
      response = get :show, {:id => bill.uid, :locale => 'es'}, valid_session
      p response.body
      assigns(:date_freq).should eq [1,0,0,0,0,0,0,0,0,4,0,0]
    end

    xit "define time lapse (weeks, months, years) in ENV" do
    end
  end

  describe "GET new" do
    xit "assigns a new bill as @bill" do
      get :new, {}, valid_session
      assigns(:bill).should be_a_new(Billit::Bill)
    end
  end

  describe "GET edit" do
    xit "assigns the requested bill as @bill" do
      bill = Billit::Bill.create! valid_attributes
      get :edit, {:id => bill.to_param}, valid_session
      assigns(:bill).should eq(bill)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      xit "creates a new Bill" do
        expect {
          post :create, {:bill => valid_attributes}, valid_session
        }.to change(Billit::Bill, :count).by(1)
      end

      xit "assigns a newly created bill as @bill" do
        post :create, {:bill => valid_attributes}, valid_session
        assigns(:bill).should be_a(Billit::Bill)
        assigns(:bill).should be_persisted
      end

      xit "redirects to the created bill" do
        post :create, {:bill => valid_attributes}, valid_session
        response.should redirect_to(Billit::Bill.last)
      end
    end

    describe "with invalid params" do
      xit "assigns a newly created but unsaved bill as @bill" do
        # Trigger the behavior that occurs when invalid params are submitted
        Billit::Bill.any_instance.stub(:save).and_return(false)
        post :create, {:bill => {  }}, valid_session
        assigns(:bill).should be_a_new(Billit::Bill)
      end

      xit "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Billit::Bill.any_instance.stub(:save).and_return(false)
        post :create, {:bill => {  }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      xit "updates the requested bill" do
        bill = Billit::Bill.get("http://billit.ciudadanointeligente.org/bills/6967-06", 'application/json')
        put :update, {id: bill.uid, tags: bill.tags, locale: 'es'}, valid_session
        assigns(:bill).tags.should eq(bill.tags)
      end

      xit "assigns the requested bill as @bill" do
        bill = Billit::Bill.create! valid_attributes
        put :update, {:id => bill.to_param, :bill => valid_attributes}, valid_session
        assigns(:bill).should eq(bill)
      end

      xit "redirects to the bill" do
        bill = Billit::Bill.create! valid_attributes
        put :update, {:id => bill.to_param, :bill => valid_attributes}, valid_session
        response.should redirect_to(bill)
      end
    end

    describe "with invalid params" do
      xit "assigns the bill as @bill" do
        bill = Billit::Bill.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Billit::Bill.any_instance.stub(:save).and_return(false)
        put :update, {:id => bill.to_param, :bill => {  }}, valid_session
        assigns(:bill).should eq(bill)
      end

      xit "re-renders the 'edit' template" do
        bill = Billit::Bill.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Billit::Bill.any_instance.stub(:save).and_return(false)
        put :update, {:id => bill.to_param, :bill => {  }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    xit "destroys the requested bill" do
      bill = Billit::Bill.create! valid_attributes
      expect {
        delete :destroy, {:id => bill.to_param}, valid_session
      }.to change(Billit::Bill, :count).by(-1)
    end

    xit "redirects to the bills list" do
      bill = Billit::Bill.create! valid_attributes
      delete :destroy, {:id => bill.to_param}, valid_session
      response.should redirect_to(bills_url)
    end
  end

end
