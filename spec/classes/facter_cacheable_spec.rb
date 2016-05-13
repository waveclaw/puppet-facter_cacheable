require 'spec_helper'

describe 'facter_cacheable' do
  context 'on supported operating systems' do
    ['Debian', 'RedHat', 'AIX', 'Solaris', 'SuSE'].each do |osfamily|
      describe "without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{
          :osfamily => osfamily,
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('facter_cacheable') }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'facter_cacheable class without any parameters on Windows' do
      let(:facts) {{
        :osfamily        => 'Microsoft',
        :operatingsystem => 'Windows',
      }}
      let(:params) {{ }}
      it { expect { is_expected.to contain_class('facter_cacheable') }.to raise_error(Puppet::Error, /Windows is not supported/) }
    end
  end
end
