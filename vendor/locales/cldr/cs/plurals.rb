# -*- encoding : utf-8 -*-
{ :cs => { :i18n => {:plural => { :keys => [:one, :few, :other], :rule => lambda { |n| n == 1 ? :one : [2, 3, 4].include?(n) ? :few : :other } } } } }
