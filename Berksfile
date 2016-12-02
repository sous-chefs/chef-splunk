source 'https://supermarket.chef.io'

metadata

cookbook 'chef-vault', '~> 1.2.0'

group :integration do
  cookbook 'test', path: './test/fixtures/cookbooks/test'
  cookbook 'yum'
end
