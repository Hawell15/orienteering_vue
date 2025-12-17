<template>
  <div class="vue-app">
    <h1>Hello from Vue 3 + Rails 7!</h1>
    <p>Counter: {{ count }}</p>
    <button @click="count++">Increment</button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
const count = ref(0)
</script>
