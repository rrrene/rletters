{ :'fr' => { i18n: { plural: { keys: [:one, :other], rule: lambda { |n| n = n.respond_to?(:abs) ? n.abs : ((m = n.to_s)[0] == "-" ? m[1,m.length] : m); [0, 1].include?(n.to_i) ? :one : :other } } } } }