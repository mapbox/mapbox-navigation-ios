require File.expand_path('../spec_helper', __FILE__)

module Liferaft
  describe Version do
    it 'compares 6D570 and 6D1002 correctly' do
      v1 = Version.new('6D570')
      v2 = Version.new('6D1002')

      v1.should < v2
      v2.should > v1
    end

    it 'implements the equality operator' do
      v1 = Version.new('6D570')
      v2 = Version.new('6D570')

      v1.should == v2
    end

    it 'implements greater-than-or-equals operator' do
      v1 = Version.new('6D570')
      v2 = Version.new('6D570')
      v3 = Version.new('6D002')

      v2.should >= v1
      v2.should >= v3
    end

    it 'implements less-than-or-equals operator' do
      v1 = Version.new('6D570')
      v2 = Version.new('6D570')
      v3 = Version.new('6D1002')

      v1.should <= v2
      v1.should <= v3
    end
  end
end
