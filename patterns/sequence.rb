a = GObj.create
b = a.async_do_sth("")
c = b.get_result
d = a.async_do_sth(c)
e = d.get_result
