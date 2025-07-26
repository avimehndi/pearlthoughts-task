terraform { 
  cloud { 
    hostname     = "app.terraform.io"
    organization = "avimehndi" 

    workspaces { 
      name = "task" 
    } 
  } 
}