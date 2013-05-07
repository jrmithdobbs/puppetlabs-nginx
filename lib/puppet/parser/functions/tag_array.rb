module Puppet::Parser::Functions
  newfunction(:tag_array, :doc => <<-'ENDHEREDOC') do |args|
    Flattens arguments and adds tags

    ENDHEREDOC

    Puppet::Parser::Functions.function('any2array')
    Puppet::Parser::Functions.function('flatten')
    Puppet::Parser::Functions.function('tag')
    args.each do |arg|
      function_tag(function_flatten([function_any2array([arg])]))
    end
  end
end
