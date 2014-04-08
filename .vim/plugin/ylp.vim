map ,fp <esc>yiw:Ag <c-r>" -G .py\|grep -v templates<cr>
map ,ft <esc>yiw:Ag <c-r>" -G .tmpl<cr>
map ,fT <esc>yiw:Ag <c-r>" -G _test.py<cr>

map ,w <esc>:w!\|!scp % dev14-devc:/nail/home/grzegorz/pg/loc/%<cr>
