NVCC = nvcc
TARGET = run
FILE = p4_template.cu

$(TARGET): $(SRC)
	$(NVCC) -o $(TARGET) $(FILE)

# Clean up
clean:
	rm -f $(TARGET)
