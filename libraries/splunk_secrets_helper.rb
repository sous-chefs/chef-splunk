module SecretsHelper
  require 'iniparse'

  # get either the encrypted secret value locally or descrypted value from the encrypted data bag
  def splunk_secret_inspect(file, section, secret_name = 'pass4SymmKey')
    key = nil
    tag = "force_#{section}_#{secret_name.downcase}_rotation"

    if node.tags.include?(tag) || file.nil?
      ::Chef::Log.info("secret rotation occurred for #{secret_name.downcase} in [#{section}]")
      node.tags.delete(tag)
    elsif ::File.exist?(file)
      document = IniParse.parse(::File.read(file))
      key = document[section][secret_name] if document.has_section?(section) && document[section].has_option?(secret_name)
    end

    key
  end

  # encrypted splunk secrets will start with `$\d$` pattern (e.g., `$6$`)
  def splunk_encrypted?(key)
    !key.nil? && key.match?(/^\$\d\$/)
  end
end

Chef::Mixin::Template::TemplateContext.include ::SecretsHelper
