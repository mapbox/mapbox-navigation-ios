require File.expand_path('../spec_helper', __FILE__)

module Liferaft
  describe Liferaft do
    it 'writes 6D570 correctly' do
      version_string = Liferaft.version_string_create(6, 3, 0, 570)

      version_string.should == '6D570'
    end

    it 'writes 6D1002 correctly' do
      version_string = Liferaft.version_string_create(6, 3, 1, 2)

      version_string.should == '6D1002'
    end
  end

  describe Version do
    it 'parses 6E7 correctly' do
      version = Version.new('6E7')

      version.major.should == 6
      version.minor.should == 4
      version.patch.should == 0
      version.build.should == 7
    end

    it 'parses 6C131e correctly' do
      version = Version.new('6C131e')

      version.major.should == 6
      version.minor.should == 2
      version.patch.should == 0
      version.build.should == 232
    end

    it 'parses 6D570 correctly' do
      version = Version.new('6D570')

      version.major.should == 6
      version.minor.should == 3
      version.patch.should == 0
      version.build.should == 570
    end

    it 'parses 6D1002 correctly' do
      version = Version.new('6D1002')

      version.major.should == 6
      version.minor.should == 3
      version.patch.should == 1
      version.build.should == 0o02
    end

    it 'parses 6E7 correctly' do
      version = Version.new('6E7')

      version.major.should == 6
      version.minor.should == 4
      version.patch.should == 0
      version.build.should == 7
    end

    it 'parses 6E14 correctly' do
      version = Version.new('6E14')

      version.major.should == 6
      version.minor.should == 4
      version.patch.should == 0
      version.build.should == 14
    end

    it 'parses 6E14 correctly' do
      version = Version.new('6E14')

      version.major.should == 6
      version.minor.should == 4
      version.patch.should == 0
      version.build.should == 14
    end

    it 'parses 16E14 correctly' do
      version = Version.new('16E14')

      version.major.should == 16
      version.minor.should == 4
      version.patch.should == 0
      version.build.should == 14
    end

    it 'parses 7A121l correctly' do
      version = Version.new('7A121l')

      version.major.should == 7
      version.minor.should == 0
      version.patch.should == 0
      version.build.should == 229
    end

    it 'is resilient against empty minor versions' do
      version = Version.new('614')

      version.major.should == 0
      version.minor.should == 0
      version.patch.should == 0
      version.build.should == 0
    end

    it 'is resilient against multi-character minor versions' do
      version = Version.new('6EEE14')

      version.major.should == 0
      version.minor.should == 0
      version.patch.should == 0
      version.build.should == 0
    end

    it 'is resilient against parsing broken versions' do
      version = Version.new('ERTTR456E')

      version.major.should == 0
      version.minor.should == 0
      version.patch.should == 0
      version.build.should == 0
    end

    it 'can convert a Version object to string' do
      version = Version.new('6E14')

      version.to_s.should == '6.4.0 Build 14'
    end
  end
end
