{ :'ur' => { i18n: { plural: { keys: [:one, :other], rule: lambda { |n| n = n.respond_to?(:abs) ? n.abs : ((m = n.to_s)[0] == "-" ? m[1,m.length] : m); (n.to_i == 1 && ((v = n.to_s.split(".")[1]) ? v.length : 0) == 0) ? :one : :other } } } } }