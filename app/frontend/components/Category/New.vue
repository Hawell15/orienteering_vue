<template>
    <Create ref="create" @save="saveCategory" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Categorie</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveCategory() {
    window.location = "/categories?sorting[direction]=desc";
}
</script>
