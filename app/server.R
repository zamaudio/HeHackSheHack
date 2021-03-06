library(rmongodb)
mongo <- mongo.create(host = "146.118.98.44")
mongo.get.databases(mongo)
db <-  "healthhack"
mongo.get.database.collections(mongo, db)
library("ggplot2")
# source("helper.R")
library("shiny")
# source("http://www.bioconductor.org/biocLite.R")
# biocLite("BSgenome")
# biocLite("BSgenome.Hsapiens.UCSC.hg19") 
library('BSgenome.Hsapiens.UCSC.hg19')
shinyServer(function(input, output) {
  
  mongoo <- reactive ({
    mongo <- mongo.create(host = "146.118.98.44")
    return(mongo)
  })
  
  get_sample<- reactive({   
    mongo <- mongoo()
    mongo.get.databases(mongo)
    db <-  "healthhack"
    mongo.get.database.collections(mongo, db)
    
    pops1 <- mongo.find.all(mongo, "healthhack.testcoverage", query = 
                              list('uid' = input$samp_sel, 'chr' = input$chr_sel, 'startpos'= as.numeric(input$pos_ins)),
                            fields=
                              list('coverage' = '1L', '_id'= '0l'))                                 
    return(pops1)
  })
  
  output$sample <- renderPrint({
    get_sample()
  })
  
  gene_seq <-  reactive({
    get_genomic_seq(input$chr_sel, as.numeric(input$pos_ins),get_sample())
    
  })
  
  output$pseq <- renderPrint({
    gene_seq ()
  })
  
  make_plot <- reactive({
    make_gplot (gene_seq (), get_sample(), input$xslide
                )
    
#     means_data(input$chr_sel,input$samp_sel
  })
  
  output$gggplot <- renderPlot({
    make_plot()
  })
    
    output$pos_inputs <- renderUI({
      mongo <- mongoo()
        mongo.get.databases(mongo)
        db <-  "healthhack"
        mongo.get.database.collections(mongo, db)
        all_pos <- mongo.find.all(mongoo(), "healthhack.testcoverage", query = 
                                    list('chr' = input$chr_sel, 'uid' = input$samp_sel), fields=
                                    list('startpos' = '1L', '_id'= '0l')) 
      
        new_pos <- unlist(all_pos , recursive = F)
        print(str(new_pos))
        snewps <-  new_pos[sapply(new_pos, is.numeric)]
        end <- as.numeric(snewps)

      selectInput("pos_ins",selectize = F,
                     label = "Select a sample", choices = end[1:20])
    })

  
})


handle_mong0 <- function(chr, pos,samp){  
  mongo <- mongoo()
  mongo.get.databases(mongo)
  db <-  "healthhack"
  mongo.get.database.collections(mongo, db)

  pops1 <- mongo.find.all(mongo, "healthhack.testcoverage", query = 
                            list('uid' = samp, 'chr' = chr, 'startpos'= pos),
                          fields=
                            list('coverage' = '1L', '_id'= '0l'))                                 
  return(pops1)
  
}

get_genomic_seq <- function(chr, pos, sample){  
  len <- length(sample[[1]]$coverage)
  seq <- getSeq(Hsapiens,chr,pos,pos+len-1)
  c_seq <-  as.character(seq)
  return(c_seq)
}

make_gplot <- function (seq, samp, slider){
  coverage <- samp[[1]]$coverage
  nums <- seq(1, length(coverage))
  sequence <- strsplit(seq, "")
  to_plot <- data.frame(sequence, coverage, nums, stringsAsFactors = F)
  colnames(to_plot) <- c("sequence", "coverage", "numbers")
  to_plot <- to_plot[
    to_plot$numbers >= slider[1] &
      to_plot$numbers <= slider[2],]
  print(head(to_plot))
  plt <- ggplot(data = to_plot, aes(x = numbers, y = coverage))+geom_line()+
    scale_x_discrete(labels=to_plot$sequence)+
    xlab("Hg19")
  return(print(plt))
  
}

# possible_inputs <- function(samp, chr){
#   
#   all_pos <- mongo.find.all(mongo, "healthhack.testcoverage", query = 
#                               list('uid' = samp, 'chr' = chr), fields=
#                               list('startpos' = '1L', '_id'= '0l')) 
#   new_pos <- unlist(all_pos , recursive = F)
#   print(str(new_pos))
#   snewps <-  new_pos[sapply(new_pos, is.numeric)]
#   return (as.numeric(snewps))
#   #   print(str(all_pos))
#   #   return(as.numeric(unlist(all_pos)))
#   
# }

# get_mean_data <- function(samp,chr){
#   all_pos <- mongo.find.all(mongo, "healthhack.testcoverage", query = 
#                               list('uid' = samp, 'chr' = chr), fields=
#                               list('coverage' = '1L', '_id'= '0l')) 
# }
# 
# all_pos <- mongo.find.all(mongo, "healthhack.testcoverage", query = 
#                             list('uid' = "sdat62", 'chr' = "chr1"), fields=
#                             list('startpos' = '1L', '_id'= '0l')) 

# means_data <- function(chr, pos, mongo){  
#   
#   mongo.get.databases(mongo)
#   db <-  "healthhack"
#   mongo.get.database.collections(mongo, db)
#   pops2 <- mongo.find.all(mongo, "healthhack.testcoverage", query = 
#                             list('chr' = "chr1", 'startpos'= list('$gte' = 161480623),
#                                  'startpos'= list('$lte' = 161480623+10000)),
#                           fields=
#                             list('coverage' = '1L', '_id'= '0l')) 
#   print(str(pops2))
#   return(pops2)
#   
# }

#"/run/user/1000/gvfs/sftp:host=146.118.98.44,user=andrew/mnt/home/andrew/ShinyApps/app"