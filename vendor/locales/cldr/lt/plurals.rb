{ :'lt' => { i18n: { plural: { keys: [:one, :few, :many, :other], rule: lambda { |n| n = n.respond_to?(:abs) ? n.abs : ((m = n.to_s)[0] == "-" ? m[1,m.length] : m); (n.to_f % 10 == 1 && (((n.to_f % 100) % 1).zero? && !(11..19).include?(n.to_f % 100))) ? :one : ((((n.to_f % 10) % 1).zero? && (2..9).include?(n.to_f % 10)) && (((n.to_f % 100) % 1).zero? && !(11..19).include?(n.to_f % 100))) ? :few : ((f = n.to_s.split(".")[1]) ? f.to_i : 0) != 0 ? :many : :other } } } } }