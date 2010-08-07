require File.expand_path('spec_helper', File.dirname(__FILE__))

class User < ActiveRecord::Base
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
  end
end