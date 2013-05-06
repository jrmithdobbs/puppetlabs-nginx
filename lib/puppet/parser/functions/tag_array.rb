module Puppet::Parser::Functions
  newfunction(:tag_array, :doc => <<-'ENDHEREDOC') do |args|
    Flattens arguments and adds tags

    ENDHEREDOC

    Puppet::Parser::Functions.function('flatten')
    Puppet::Parser::Functions.function('tag')
    function_tag(function_flatten(args))
  end
end
