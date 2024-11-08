# OIDC issuer
# Obtain fingerprint with:
# server=storage.googleapis.com
# openssl s_client -servername "${server}" -showcerts -connect "${server}":443 < /dev/null 2>/dev/null | \
#   openssl x509 -in /dev/stdin -fingerprint -sha1 -noout | \
#   sed 's/://g' | \
#   awk -F= '{print tolower($2)}'

resource "aws_iam_openid_connect_provider" "minikube" {
  url = "https://storage.googleapis.com/dronenb-kubecon-2024-demo"

  client_id_list = [
    "https://storage.googleapis.com/dronenb-kubecon-2024-demo",
    "sts.amazonaws.com" # Required audience for secrets store CSI driver: https://github.com/aws/secrets-store-csi-driver-provider-aws/blob/b8df4953967406978a6199ab5321ee2308a387a7/auth/auth.go#L32
  ]

  thumbprint_list = ["cf23df2207d99a74fbe169e3eba035e633b65d94"]
}
