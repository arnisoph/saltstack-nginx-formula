#!jinja|yaml

{% from "nginx/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('nginx:lookup')) %}

nginx:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}
  service:
    - {{ datamap.service.state|default('running') }}
    - name: {{ datamap.service.name|default('nginx') }}
    - enable: {{ datamap.service.enable|default(True) }}
    - require:
      - pkg: nginx
