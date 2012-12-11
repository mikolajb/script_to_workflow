a = GObj.create

b = a.async_do_sth
c = b.get_result

e = nil
loop do
  d = a.async_do_sth(c)
  e = d.get_result
end
f = a.async_do_sth(e)
g = f.get_result
