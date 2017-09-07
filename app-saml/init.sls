#
# Ubiquitous Moodle
#
# @author Luke Carrier <luke@carrier.im>
# @author Sascha Peter <sascha.o.peter@gmail.com>
# @copyright 2017 Sascha Peter
#

include:
  - base
  - app-base

{% set platforms = salt['pillar.get']('platforms') | selectattr('saml', 'defined') %}
{% for domain, platform in platforms %}
app-saml.{{ domain }}.nginx.available:
  file.managed:
    - name: /etc/nginx/sites-available/{{ platform['basename'] }}.conf
    - source: salt://app-saml/nginx/platform.conf.jinja
    - template: jinja
    - context:
      domain: {{ domain }}
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: nginx
{% if pillar['systemd']['apply'] %}
    - onchanges_in:
      - service: app-saml.nginx.restart
{% endif %}

app-saml.{{ domain }}.nginx.enabled:
  file.symlink:
    - name: /etc/nginx/sites-enabled/{{ platform['basename'] }}.conf
    - target: /etc/nginx/sites-available/{{ platform['basename'] }}.conf
    - require:
      - file: app-saml.{{ domain }}.nginx.available
{% if pillar['systemd']['apply'] %}
    - onchanges_in:
      - service: app-saml.nginx.restart
{% endif %}

app-saml.{{ domain }}.conf:
  file.directory:
    - name: {{ platform['user']['home'] }}/conf
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0770

app-saml.{{ domain }}.conf.config:
  file.directory:
    - name: {{ platform['user']['home'] }}/conf/config
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0770
    - require:
      - app-saml.{{ domain }}.conf

app-saml.{{ domain }}.conf.cert:
  file.directory:
    - name: {{ platform['user']['home'] }}/conf/cert
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0770
    - require:
      - app-saml.{{ domain }}.conf

app-saml.{{ domain }}.conf.metadata:
  file.directory:
    - name: {{ platform['user']['home'] }}/conf/metadata
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0770
    - require:
      - app-saml.{{ domain }}.conf

app-saml.{{ domain }}.conf.modules:
  file.directory:
    - name: {{ platform['user']['home'] }}/conf/modules
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0770
    - require:
      - app-saml.{{ domain }}.conf

{% for file in platform['saml']['config'].keys() %}
app-saml.{{ domain }}.conf.config.{{ file }}:
  file.managed:
    - name: {{ platform['user']['home'] }}/conf/config/{{ file }}.php
    - source: salt://app-saml/saml/config.php.jinja
    - template: jinja
    - context:
      php_source_pillar: platforms:{{ domain }}:saml:config:{{ file }}
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0640
    - require:
      - app-saml.{{ domain }}.conf.config
{% endfor %}

{% for module, status in platform['saml']['modules'].items() %}
{% if status %}
app-saml.{{ domain }}.saml.{{ module }}:
  file.managed:
    - name: {{ platform['user']['home'] }}/conf/modules/{{ module }}/enable
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['nam{{ file }}e'] }}
    - mode: 0640
    - makedirs: True
{% else %}
app-saml.{{ domain }}.saml.{{ module }}:
  file.absent:
    - name: {{ platform['user']['home'] }}/conf/modules/{{ module }}/enable
{% endif %}
{% endfor %}

{% for file, value in platform['saml']['cert'].items() %}
app-saml.{{ domain }}.saml.cert.{{ file }}:
  file.managed:
    - name: {{ platform['user']['home'] }}/conf/cert/{{ file }}
    - contents_pillar: platforms:{{ domain }}:saml:cert:{{ file }}
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0660
{% endfor %}

{% for file in platform['saml']['metadata'].keys() %}
app-saml.{{ domain }}.saml.metadata.{{ file }}:
  file.managed:
    - name: {{ platform['user']['home'] }}/conf/metadata/{{ file }}.php
    - source: salt://app-saml/saml/config.php.jinja
    - template: jinja
    - context:
      php_source_pillar: platforms:{{ domain }}:saml:metadata:{{ file }}
    - user: {{ platform['user']['name'] }}
    - group: {{ platform['user']['name'] }}
    - mode: 0660
{% endfor %}

app-saml.nginx.reload:
  service.running:
    - name: nginx
    - reload: true

{% lets_encrypt_all('moodle', platforms) %}
