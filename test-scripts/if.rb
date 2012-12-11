a = GObj.create

b1 = a.async_do_sth
c1 = b1.get_result
b2 = a.async_do_sth
c2 = b2.get_result

d = nil
if 0 == 2
  d = a.async_do_sth(c1)
elsif 1 ==2
  d = a.async_do_sth_else(c1)
else
  d = a.async_do_sth_else2(c2)
end
e = d.get_result
f = a.async_do_sth(e)
g = f.get_result
