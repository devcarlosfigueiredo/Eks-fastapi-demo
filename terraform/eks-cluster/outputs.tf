output "cluster_name"          { value = aws_eks_cluster.main.name }
output "cluster_endpoint"      { value = aws_eks_cluster.main.endpoint }
output "cluster_ca"            { value = aws_eks_cluster.main.certificate_authority[0].data }
output "ecr_repository_url"    { value = aws_ecr_repository.app.repository_url }
output "app_role_arn"          { value = aws_iam_role.app.arn }
output "alb_controller_arn"    { value = aws_iam_role.alb_controller.arn }
output "oidc_provider_arn"     { value = aws_iam_openid_connect_provider.eks.arn }
output "vpc_id"                { value = module.vpc.vpc_id }
output "private_subnets"       { value = module.vpc.private_subnets }

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
