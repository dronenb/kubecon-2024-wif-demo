resource "aws_iam_role" "minikube_secrets_role" {
  name = "minikube-secrets-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${aws_iam_openid_connect_provider.minikube.arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "storage.googleapis.com/dronenb-kubecon-2024-demo:sub" : "system:serviceaccount:default:default",
            "storage.googleapis.com/dronenb-kubecon-2024-demo:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}