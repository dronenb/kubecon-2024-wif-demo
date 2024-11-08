resource "aws_secretsmanager_secret" "example" {
  name = "example-aws-secret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = "secret-from-aws"
}

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

resource "aws_iam_policy" "policy" {
  name        = "minikube_secret_access_policy"
  path        = "/"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource" : ["${aws_secretsmanager_secret.example.arn}"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_policy_attachment" {
  role       = aws_iam_role.minikube_secrets_role.name
  policy_arn = aws_iam_policy.policy.arn
}
