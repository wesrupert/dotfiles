{{ if eq .chezmoi.os "darwin" -}}
#!/usr/bin/env bash

brew bundle --file=/dev/stdin <<EOF
{{ range .packages.darwin.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.casks -}}
cask {{ . | quote }}
{{ end -}}
EOF

{{ if .chezmoi.config.data -}}
{{ if eq .chezmoi.config.data.context "work" -}}
brew bundle --file=/dev/stdin <<EOF
{{ range .packages.darwin.work.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.work.casks -}}
cask {{ . | quote }}
{{ end -}}
EOF
{{ end -}}

{{ if eq .chezmoi.config.data.context "home" -}}
brew bundle --file=/dev/stdin <<EOF
{{ range .packages.darwin.home.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.home.casks -}}
cask {{ . | quote }}
{{ end -}}
EOF
{{ end -}}
{{ end -}}

{{ end -}}