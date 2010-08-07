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
      
      it "should have the correct for attribute" do
        @builder.text_field(:name).should have_tag('label[@for=user_name]')
      end
      
      it "should include requirement indication if attribute is required" do
        p @builder.text_field(:email)
        @builder.text_field(:email).should have_tag('label > abbr', '*')
      end
    end
  end
end