//=================================
//      parameter config
//=================================

//  feature information
`define FEATURE_SIZE                    i_param_cfg_feature[9:0]
`define FEATURE_CHANNEL                 i_param_cfg_feature[19:10]
//  weight information
`define WEIGHT_SIZE                     i_param_cfg_weight [9:0]
`define WEIGHT_CHANNEL                  i_param_cfg_weight [19:10]
`define NUMBER_OF_WEIGHT                i_param_cfg_weight [29:20]
`define STRIDE                          i_param_cfg_weight [31:30]
`define TOTAL_WEIGHT_PIXEL              `WEIGHT_SIZE*`WEIGHT_SIZE

`define RESULT_BASED_ADDRESS            4096

//-----------------------------------------------
// Deconvolution Opertion Top information
//-----------------------------------------------
// Eachcol -> shift_reg -> Deconv top size
`define DECONV_EACHCOL_RESULT_SIZE      `WEIGHT_SIZE*`FEATURE_SIZE 
`define SHIFT_REGISTER_RESULT_SIZE      `DECONV_EACHCOL_RESULT_SIZE + `STRIDE
`define RESULT_BASED_ADDRESS            4096
`define DECONV_TOP_RESULT_SIZE          10

//-----------------------------------------------
// Poss processor information
//-----------------------------------------------
// Overlap processor
`define NON_OVERLAPPED_CONST            (`FEATURE_SIZE/2) * `STRIDE
`define OVERLAP_PROCESSOR_INPUT_SIZE    `STRIDE * (`FEATURE_SIZE/2-1) + `WEIGHT_SIZE
`define OVERLAP_PROCESSOR_OUTPUT_SIZE   2*`OVERLAP_PROCESSOR_INPUT_SIZE - (`OVERLAP_PROCESSOR_INPUT_SIZE - `NON_OVERLAPPED_CONST)
// Data tilling and gather
`define DATA_TILLING_INPUT_SIZE        `OVERLAP_PROCESSOR_OUTPUT_SIZE
`define DATA_TILLING_RESULT_SIZE        (`DATA_TILLING_INPUT_SIZE/2)*(`DATA_TILLING_INPUT_SIZE/2)