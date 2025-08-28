{{/*
Expand the name of the chart.
*/}}
{{- define "file-sharing-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "file-sharing-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "file-sharing-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "file-sharing-app.labels" -}}
helm.sh/chart: {{ include "file-sharing-app.chart" . }}
{{ include "file-sharing-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "file-sharing-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "file-sharing-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "file-sharing-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "file-sharing-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image name helper
*/}}
{{- define "file-sharing-app.image" -}}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s" .Values.global.imageRegistry .repository .tag }}
{{- else }}
{{- printf "%s:%s" .repository .tag }}
{{- end }}
{{- end }}

{{/*
Security context helper
*/}}
{{- define "file-sharing-app.securityContext" -}}
{{- if .Values.security.securityContext }}
{{- toYaml .Values.security.securityContext }}
{{- end }}
{{- end }}

{{/*
Network policy helper
*/}}
{{- define "file-sharing-app.networkPolicy" -}}
{{- if .Values.networkPolicy.enabled }}
{{- toYaml .Values.networkPolicy }}
{{- end }}
{{- end }}
