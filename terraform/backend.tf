terraform { 
  cloud { 
    
    organization = "avimehndi" 

    workspaces { 
      name = "task" 
    } 
  } 
}