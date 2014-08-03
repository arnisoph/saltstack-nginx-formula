#!jinja|yaml

{% from "nginx/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('nginx:lookup')) %}

include: {{ salt['pillar.get']('nginx:lookup:sls_include', []) }}
extend: {{ salt['pillar.get']('nginx:lookup:sls_extend', {}) }}

nginx:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs|default(['nginx']) }}
  service:
    - {{ datamap.service.ensure|default('running') }}
    - name: {{ datamap.service.name|default('nginx') }}
    - enable: {{ datamap.service.enable|default(True) }}
    - watch:
      - pkg: nginx #TODO remove
{% for k, v in salt['pillar.get']('nginx:vhosts', {}).items() %}
      - file: vhost_{{ k }}
      - cmd: manage_site_{{ k }}
{% endfor %}

{% for k, v in salt['pillar.get']('nginx:vhosts', {}).items() %}
  {% if v.ensure|default('managed') in ['managed'] %}
    {% set f_fun = 'managed' %}
  {% elif v.ensure|default('managed') in ['absent'] %}
    {% set f_fun = 'absent' %}
  {% endif %}

  {% set v_name = v.name|default(k) %}

vhost_{{ k }}:
  file:
    - {{ f_fun }}
    - name: {{ v.path|default(datamap.vhosts.dir ~ '/' ~ datamap.vhosts.name_prefix|default('') ~ v_name ~ datamap.vhosts.name_suffix|default('')) }}
    - user: root
    - group: root
    - mode: 600
    - contents_pillar: nginx:vhosts:{{ v_name }}:plain

manage_site_{{ k }}:
  cmd:
    - run
    {% if f_fun in ['managed'] %}
    - name: ln -s /etc/nginx/sites-available/{{ v_name }} /etc/nginx/sites-enabled/{{ v_name }}
    - unless: test -L /etc/nginx/sites-enabled/{{ v.linkname|default(v_name) }}
    {% else %}
    - name: rm /etc/nginx/sites-enabled/{{ v_name }}
    - onlyif: test -L /etc/nginx/sites-enabled/{{ v.linkname|default(v_name) }}
    {% endif %}
{% endfor %}
