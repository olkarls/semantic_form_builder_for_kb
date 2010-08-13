require File.expand_path('spec_helper', File.dirname(__FILE__))

class User < ActiveRecord::Base
  validates_presence_of :email
end

class SomeController < ActionController::Base
end

module SemanticFormBuilder
  describe FormBuilder do
    before do
      @controller = SomeController.new
      @user = User.new
      @builder = SemanticFormBuilder::FormBuilder.new(:user, @user, @controller.view_context, {}, Proc.new {})
    end

    describe '#field_wrapper' do
      context 'Always' do
        it 'should have a correct id' do
          @builder.text_field(:name).should have_tag('div#wrapper_user_name')
          @builder.text_field(:bio).should have_tag('div#wrapper_user_bio')
        end
        
        it 'should have the correct classes' do
          @builder.text_field(:name).should have_tag('div.control_wrapper')
        end
        
        it 'should include required class if attribute is required' do
          @builder.text_field(:email).should have_tag('div.required')
        end
      end
      
      context 'Valid attribute' do
        it 'should not include error class' do
          @builder.text_field(:name).should_not have_tag('div.field_with_error')
        end
      end
      
      context 'Unvalid attribute' do
        before do
          @user.errors[:name] << "Name is required"
        end
        
        it 'should include error class' do
          @builder.text_field(:name).should have_tag('div.field_with_error')
        end
      end
    end
    
    describe '#field_error' do
      it "should not be included if attribute is valid" do
        @builder.text_field(:name).should_not have_tag('span.error_message')
      end
      
      it "should be included if attribute is not valid" do
        msg = 'Name is required'
        @user.errors[:name] << msg
        @builder.text_field(:name).should have_tag('span.error_message', msg)
      end
      
      it 'should only include the first error' do
        msg = 'Name is required'
        @user.errors[:name] << msg
        @user.errors[:name] << 'Second error'
        @builder.text_field(:name).should have_tag('span.error_message', msg)
        @builder.text_field(:name).should_not have_tag('span.error_message', 'Second error')
      end
    end
    
    describe '#field_hint' do
      it "should not be present if argument is not passed" do
        @builder.text_field(:name).should_not have_tag('span.field_hint')
      end
      
      it "should be present if argument is passed" do
        @builder.text_field(:name, :hint => 'Some hint').should have_tag('span.field_hint', 'Some hint')
      end
      
      it "should not be present if there is an error on the attribute" do
        @user.errors[:name] << "Error message"
        @builder.text_field(:name, :hint => 'Some hint').should_not have_tag('span.field_hint', 'Some hint')
        @builder.text_field(:name).should have_tag('span.error_message', 'Error message')
      end
    end
    
    describe '#field_label' do
      it "should include translation_key if no label_text is supplied" do
        @builder.text_field(:name).should have_tag('label', 'Translation missing: en, name: ')
      end
      
      it "should have the label_text if it is supplied" do
        @builder.text_field(:name, :label => "Label text").should have_tag('label', 'Label text')
      end
      
      it "should have the correct for attribute" do
        @builder.text_field(:name).should have_tag('label[@for=user_name]')
      end
      
      it "should include requirement indication if attribute is required" do
        @builder.text_field(:email).should have_tag('label > abbr', '*')
      end
      
      it "should include classes if supplied" do
        @builder.text_field(:name, :label_class => "name").should have_tag('label.name')
      end
      
      it "should include classes if supplied and the required class if attribute is required" do
        @builder.text_field(:email, :label_class => "name other_class").should have_tag('label.name.required.other_class')
      end
    end
    
    describe '#phone_field' do
      it "should have the correct html5 type" do
        @builder.phone_field(:email).should have_tag('input[@type=tel]')
      end
    end
    
    describe '#email_field' do
      it "should have the correct html5 type" do
        @builder.email_field(:email).should have_tag('input[@type=email]')
      end
    end
    
    describe '#url_field' do
      it "should have the correct html5 type" do
        @builder.url_field(:email).should have_tag('input[@type=url]')
      end
    end
    
    describe '#telephone_field' do
      it "should have the correct html5 type" do
        @builder.telephone_field(:email).should have_tag('input[@type=tel]')
      end
    end
    
    describe '#search_field' do
      it "should have the correct html5 type" do
        @builder.search_field(:email).should have_tag('input[@type=search]')
      end
    end
    
    describe '#numeric_field' do
      it "should have the correct html5 type" do
        @builder.numeric_field(:email).should have_tag('input[@type=number]')
      end
    end
    
    describe 'placeholder attribute' do
      it 'should be included if supplied' do
        @builder.text_field(:email, :placeholder => "user@example.com").should have_tag('input[@placeholder="user@example.com"]')
        @builder.email_field(:email, :placeholder => "user@example.com").should have_tag('input[@placeholder="user@example.com"]')
      end
    end
    
    describe '#submit' do
      it "should have type submit" do
        @builder.submit().should have_tag('button[@type=submit]')
      end
      
      it "should have a nested span" do
        @builder.submit().should have_tag('button > span')
      end
      
      it "should have the correct text" do
        @builder.submit("Don't click on me").should have_tag('button > span', "Don't click on me")
      end
      
      it "should include translation_key if no text is supplied" do
        @builder.submit().should have_tag('button > span', "translation missing: en, save")
      end
      
      it "should have name commit if no name is supplied" do
        @builder.submit().should have_tag('button[@name=commit]')
      end
      
      it "should be possible to override name attribute" do
        @builder.submit(nil, :name => 'unlucky_luke').should have_tag('button[@name=unlucky_luke]')
      end
      
      it "should be possible to set classes" do
        @builder.submit(nil, :class => 'unlucky_luke').should have_tag('button.unlucky_luke')
      end
      
      it "should be possible to set id" do
        @builder.submit(nil, :id => 'unlucky_luke').should have_tag('button#unlucky_luke')
      end
    end
    
    describe '#check_box' do
      it "should include checkbox" do
        @builder.check_box(:accepted_terms).should have_tag('input[@type=checkbox]')
      end
      
      it "should include label after checkbox" do
        @builder.check_box(:accepted_terms).should have_tag('input, input, label')
      end
    end
    
    describe '#radio_buttons' do
      it "should have correct name attribute" do
        @builder.radio_buttons(:role, ["user", "admin"]).should have_tag('input[@name="user[role]"]')
      end
      
      it "should include collection as radio_buttons" do
        @builder.radio_buttons(:role, ["user", "admin"]).should have_tag('input[@value="user"]')
        @builder.radio_buttons(:role, ["user", "admin"]).should have_tag('input[@value="admin"]')
      end
      
      context 'Model collection' do
        before do
          @users = []
          @users << User.create(:email => "test@test.se")
          @users << User.create(:email => "test@test.se")
          @users << User.create(:email => "test@test.se")
          @users << User.create(:email => "test@test.se")
          @users << User.create(:email => "test@test.se")
        end
      
        it "should be possible to pass models as collection" do
          @builder.radio_buttons(:role, @users, :id, :email).should have_tag('input[@type=radio]', :count => 5)
        end
      
        it "should associate label with input" do
          @builder.radio_buttons(:role, @users, :id, :email).should have_tag("input#user_role_#{@users.first.id}")
          @builder.radio_buttons(:role, @users, :id, :email).should have_tag("label[for=user_role_#{@users.first.id}]")
          @builder.radio_buttons(:admin, @users, :id, :email).should have_tag("input#user_admin_#{@users.first.id}")
          @builder.radio_buttons(:admin, @users, :id, :email).should have_tag("label[for=user_admin_#{@users.first.id}]")
        end
      end
    end
    
    describe '#fieldset' do
      it "should return a fieldset with nested content" do
        @builder.fieldset { "fieldset content" }.should have_tag('fieldset', 'fieldset content')
      end
      
      it "should include legend if argument is passed" do
        @builder.fieldset(:legend => "Legend text") { }.should have_tag('fieldset > legend', 'Legend text')
      end
      
      it "should be able to set classes" do
        @builder.fieldset(:class => "fieldset_class") { }.should have_tag('fieldset.fieldset_class')
      end
      
      it "should be able to set id" do
        @builder.fieldset(:id => "fieldset_id") { }.should have_tag('fieldset#fieldset_id')
      end
      
      it "should raise error if no block is given" do
        lambda { @builder.fieldset }.should raise_error
      end
    end
  end
end