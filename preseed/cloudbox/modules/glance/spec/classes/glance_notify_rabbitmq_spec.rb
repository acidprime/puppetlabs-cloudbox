require 'spec_helper'
describe 'glance::notify::rabbitmq' do
  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
      :osfamily => 'Debian'
    }
  end
  describe 'with default parameters' do
    it 'should set nofier strategy to rabbit' do
      verify_contents(
        subject,
        '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/06_glance-api-notify',
        ['notifier_strategy = rabbit']
      )
    end
    it 'should use the current rabbitmq template' do
      verify_contents(
        subject,
        '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/07_glance-api-rabbitmq',
        ['#rabbit_port = 5672']
      )
    end
  end
end
