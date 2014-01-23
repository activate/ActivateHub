module TaskHelpers
  def self.parse_var_args(args)
    args.inject({}) do |options,(key,val)|
      if key =~ /\Aargv/
        # unnamed arg (key name defined in variable value, x=1 or x:1)
        if !val.present? || val[0] == ':' || val[0] == '='
          # unnamed arg doesn't have a key/name, ignore
        elsif val =~ /\A([^:=]+)[:=](.*)\Z/
          options[$1.to_sym] = $2
        elsif val =~ /\A!(.+?)\Z/
          options[$1.to_sym] = false
        else
          options[val.to_sym] = true
        end
      else
        # standard task-defined arg (hard-coded in task definition)
        options[key] = val
      end

      options
    end
  end
end
