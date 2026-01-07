<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> {{category.full_name}}</h1>
        <p><strong>Denumirea: </strong>{{category.category_name}}</p>
        <hr class="my-4">
        <p><strong>Puncte: </strong>{{category.points}}</p>
        <p><strong>Validitate: </strong>{{category.validaty_period}} ani</p>
        <p><strong>Numarul de sportivi: </strong><a :href="`/runners?category=${category.id}`">{{category.runners.length}}</a></p>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editCategory(category)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteCategory(category.id)">Sterge</button>
    </p>
    <CategoryModal ref="modal" :category="modalCategory" :isNew="false" @save="saveCategory" />
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const category = ref({ runners: [] })
onMounted(() => {
 getData()
})

async function getData() {
  const id = window.location.pathname.split('/').pop();
    const res = await axios.get(`/categories/${id}.json`)
    category.value = res.data;
}
</script>
