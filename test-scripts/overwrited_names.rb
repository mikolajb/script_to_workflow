a = GObj.create
b = a.async_do_sth
c = b.get_result
b = a.async_do_sth(c)
c = b.get_result
b = a.async_do_sth(c)
c = b.get_result
