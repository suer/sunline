require 'spec_helper'

describe ScriptsController, type: :controller  do

  before do
    user = User.new(name: 'name', nickname: 'nickname')
    user.save
    sign_in user
  end

  describe 'index' do
    context 'archived scripts' do
      before do
        @script = Script.new(name: 'name', archived: true)
        @script.save
        get :index, archived: 'true'
      end
      subject { assigns[:scripts].find {|script| script.id == @script.id } }
      it { is_expected.not_to be_nil }
    end

    context 'active scripts' do
      before do
        @script = Script.new(name: 'name', archived: false)
        @script.save
        get :index
      end
      subject { assigns[:scripts].find {|script| script.id == @script.id } }
      it { is_expected.not_to be_nil }
    end
  end

  context 'archive' do
    before do
      @script = Script.new(name: 'name', archived: nil)
      @script.save
      post :archive, id: @script.id
    end
    subject { Script.find(@script.id) }
    its(:archived) { is_expected.to be_truthy }
  end

  context 'unarchive' do
    before do
      @script = Script.new(name: 'name', archived: true)
      @script.save
      post :unarchive, id: @script.id
    end
    subject { Script.find(@script.id) }
    its(:archived) { is_expected.to be_falsy }
  end

  context 'runnable_script' do
    before do
      @script = Script.new(name: 'name', body: 'ls -l')
      @script.save
      get :sh, guid: @script.guid
    end
    it { expect(response.body).to be_include 'ls -l' }
  end

  context 'remote_script' do
    before do
      @script = Script.new(name: 'name', body: 'ls -l')
      @script.save
      get :wrapped_sh, guid: @script.guid
    end
    it { expect(response.body).to be_include 'tee' }
  end
end
