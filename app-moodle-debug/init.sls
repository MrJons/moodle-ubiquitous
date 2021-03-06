#
# Ubiquitous Moodle
#
# @author Luke Carrier <luke@carrier.im>
# @copyright 2018 The Ubiquitous Authors
#

include:
- app-moodle
- app-debug

{% for domain, platform in salt['pillar.get']('platforms', {}).items() if 'moodle' in platform %}
{% set behat_faildump = platform['user']['home'] + '/data/behat-faildump' %}

app-moodle-debug.{{ domain }}.behat-faildump:
  file.directory:
  - name: {{ behat_faildump }}
  - user: {{ platform['user']['name'] }}
  - group: {{ platform['user']['name'] }}
  - mode: 0770

{% if pillar['acl']['apply'] %}
app-moodle-debug.{{ domain }}.behat-faildump.acl:
  acl.present:
  - name: {{ behat_faildump }}
  - acl_type: user
  - acl_name: {{ pillar['nginx']['user'] }}
  - perms: rx
  - require:
    - app-moodle-debug.{{ domain }}.behat-faildump
{% endif %}

app-moodle-debug.{{ domain }}.nginx:
  file.managed:
    - name: /etc/nginx/sites-extra/{{ platform['basename'] }}.moodle-debug.conf
    - source: salt://app-moodle-debug/nginx/platform.moodle-debug.conf.jinja
    - template: jinja
    - context:
      domain: {{ domain }}
    - user: root
    - group: root
    - mode: 0644
{% if pillar['systemd']['apply'] %}
    - onchanges_in:
      - app-moodle-debug.nginx.reload
{% endif %}
{% endfor %}

app-moodle-debug.nginx.reload:
  cmd.run:
    - name: systemctl reload nginx || systemctl restart nginx
