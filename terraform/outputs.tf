output "k8s_master_public_ip" {
  description = "Public IP of the K8s master node"
  value       = aws_instance.k8s_master.public_ip
}

output "k8s_worker_1_public_ip" {
  description = "Public IP of the K8s worker 1 node"
  value       = aws_instance.k8s_workers[0].public_ip
}

output "k8s_worker_2_public_ip" {
  description = "Public IP of the K8s worker 2 node"
  value       = aws_instance.k8s_workers[1].public_ip
}