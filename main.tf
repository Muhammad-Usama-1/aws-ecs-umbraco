


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "white-hart"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  
 family             = "my-ecs-task"
 network_mode       = "awsvpc"
 requires_compatibilities = ["FARGATE"] # The valid values are EC2 and FARGATE.
#  This role is for , allowing creating logs , etc , not for the container
 execution_role_arn = "arn:aws:iam::865614714682:role/ecsTaskExecutionRole"
 cpu                = 256
 skip_destroy =true


 volume {
    name = "service-storage"
    efs_volume_configuration {
      # Change EFS ID
      file_system_id          = aws_efs_file_system.fs.id
      # root_directory          = "/publish/wwwroot"  
    }
  }
 runtime_platform {  
   operating_system_family = "LINUX" 
   
   cpu_architecture        = "X86_64"  #  The valid values are X86_64 and ARM64.
 }
 memory = "512"
  container_definitions = file("task-definitions/webserver.json")

}


resource "aws_lb" "ecs_alb" {
 name               = "ecs-alb"
 internal           = false
 load_balancer_type = "application"
 #chnage SG, and subnet
 security_groups    = [aws_security_group.security_group.id]
#  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
 subnets = [for i in range(length(var.public_subnet_cidr_blocks)) : aws_subnet.public[i].id]


 tags = {
   Name = "ecs-alb"
 }
}

resource "aws_lb_listener" "ecs_alb_listener" {
 load_balancer_arn = aws_lb.ecs_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ecs_tg.arn
 }
}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
#  CHnage vpc ID
 vpc_id      = aws_vpc.default.id

 health_check {
   path = "/"
 }
}


resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 launch_type     = "FARGATE"
 cluster         = aws_ecs_cluster.ecs_cluster.id
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 1
  network_configuration {
    security_groups = [aws_security_group.security_group.id]
    subnets         = aws_subnet.private.*.id
  }


 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "sample-fargate-app"
   container_port   = 80
 }

}