# -*- encoding : utf-8 -*-
{ :fr => { :i18n => {:plural => { :keys => [:one, :other], :rule => lambda { |n| n && n != 2 ? :one : :other } } } } }
