# klustre-csi-plugin

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.1](https://img.shields.io/badge/AppVersion-0.1.1-informational?style=flat-square)

Deploys the Klustre CSI node plugin for Lustre volumes.

**Homepage:** <https://github.com/klustrefs/klustre-csi-plugin>

## Source Code

* <https://github.com/klustrefs/klustre-csi-plugin>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| csiDriver.create | bool | `true` |  |
| csiDriver.fsGroupPolicy | string | `"ReadWriteOnceWithFSType"` |  |
| csiDriver.name | string | `"lustre.csi.klustrefs.io"` |  |
| extraVolumeMounts | list | `[]` |  |
| extraVolumes | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"ghcr.io/klustrefs/klustre-csi-plugin"` |  |
| image.tag | string | `"0.1.1"` |  |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| namespace.create | bool | `true` |  |
| namespace.labels."pod-security.kubernetes.io/enforce" | string | `"privileged"` |  |
| namespace.name | string | `"klustre-system"` |  |
| nodePlugin.csiEndpoint | string | `"unix:///var/lib/kubelet/plugins/lustre.csi.klustrefs.io/csi.sock"` |  |
| nodePlugin.hostPaths.device | string | `"/dev"` |  |
| nodePlugin.hostPaths.lib | string | `"/lib"` |  |
| nodePlugin.hostPaths.lib64 | string | `"/lib64"` |  |
| nodePlugin.hostPaths.pods | string | `"/var/lib/kubelet/pods"` |  |
| nodePlugin.hostPaths.sbin | string | `"/sbin"` |  |
| nodePlugin.hostPaths.usrSbin | string | `"/usr/sbin"` |  |
| nodePlugin.imagePullSecrets | list | `[]` |  |
| nodePlugin.kubeletRegistrationPath | string | `"/var/lib/kubelet/plugins/lustre.csi.klustrefs.io/csi.sock"` |  |
| nodePlugin.ldLibraryPath | string | `"/host/lib:/host/lib64:/host/usr/lib:/host/usr/lib64"` |  |
| nodePlugin.logLevel | string | `"info"` |  |
| nodePlugin.pathEnv | string | `"/host/usr/sbin:/host/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"` |  |
| nodePlugin.pluginDir | string | `"/var/lib/kubelet/plugins/lustre.csi.klustrefs.io"` |  |
| nodePlugin.priorityClassName | string | `"system-node-critical"` |  |
| nodePlugin.registrar.image.pullPolicy | string | `"IfNotPresent"` |  |
| nodePlugin.registrar.image.repository | string | `"registry.k8s.io/sig-storage/csi-node-driver-registrar"` |  |
| nodePlugin.registrar.image.tag | string | `"v2.10.1"` |  |
| nodePlugin.registrar.resources.limits.cpu | string | `"200m"` |  |
| nodePlugin.registrar.resources.limits.memory | string | `"200Mi"` |  |
| nodePlugin.registrar.resources.requests.cpu | string | `"100m"` |  |
| nodePlugin.registrar.resources.requests.memory | string | `"200Mi"` |  |
| nodePlugin.registrationDir | string | `"/var/lib/kubelet/plugins_registry"` |  |
| nodePlugin.resources.limits.cpu | string | `"200m"` |  |
| nodePlugin.resources.limits.memory | string | `"200Mi"` |  |
| nodePlugin.resources.requests.cpu | string | `"50m"` |  |
| nodePlugin.resources.requests.memory | string | `"50Mi"` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| rbac.create | bool | `true` |  |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| settingsConfigMap.create | bool | `true` |  |
| storageClass.allowedTopologies[0].matchLabelExpressions[0].key | string | `"lustre.csi.klustrefs.io/lustre-client"` |  |
| storageClass.allowedTopologies[0].matchLabelExpressions[0].values[0] | string | `"true"` |  |
| storageClass.annotations | object | `{}` |  |
| storageClass.create | bool | `true` |  |
| storageClass.mountOptions[0] | string | `"flock"` |  |
| storageClass.mountOptions[1] | string | `"user_xattr"` |  |
| storageClass.name | string | `"klustre-csi-static"` |  |
| storageClass.parameters | object | `{}` |  |
| storageClass.reclaimPolicy | string | `"Retain"` |  |
| storageClass.volumeBindingMode | string | `"WaitForFirstConsumer"` |  |
| tolerations[0].operator | string | `"Exists"` |  |
| topologySpreadConstraints | list | `[]` |  |

