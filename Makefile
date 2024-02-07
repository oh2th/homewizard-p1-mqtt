prefix = /usr/local
systemctldir = /etc/systemd/system/
progname = homewizard-p1-mqtt

install: $(prefix)/bin/$(progname).pl $(prefix)/etc/$(progname).conf $(systemctldir)/$(progname).service

$(prefix)/bin/$(progname).pl: $(progname).pl
	cp $(progname).pl $(prefix)/bin
	chmod 755 $(prefix)/bin/$(progname).pl

$(systemctldir)/$(progname).service: $(progname).service
	cp $(progname).service $(systemctldir)

$(prefix)/etc/$(progname).conf: $(progname).conf
	cp -p $< $@

enable:
	systemctl enable $(progname).service

disable:
	systemctl disable $(progname).service

start:
	systemctl start $(progname).service

restart:
	systemctl restart $(progname).service

stop:
	systemctl stop $(progname).service

